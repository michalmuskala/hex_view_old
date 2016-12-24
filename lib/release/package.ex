defmodule DistilleryPackage do
  use Mix.Releases.Plugin

  ## Distillery hooks

  def before_assembly(release, _opts) do
    release
  end

  def after_assembly(release, _opts) do
    release
  end

  def before_package(release, _opts) do
    release
  end

  def after_package(release, _opts) do
    info("Building .deb package...")
    make_workdir(workdir(), release)
    unpack_release(workdir(), archive_path(release, "tar.gz"), release)
    add_lifetime_scripts(workdir(), release)
    add_init_script(workdir(), release)
    handle_config(workdir(), release)
    compress(workdir(), "data", release)
    add_control_file(workdir(), release)
    compress(workdir(), "control", release)
    build_package(workdir(), release)
    clean_workdir(workdir(), release)
    release
  end

  def after_cleanup(release, _opts) do
    release
  end

  ## Packaging steps

  defp make_workdir(path, _release) do
    debug("Setting up packaging directory in: #{path}")
    File.mkdir_p!(path)
    File.mkdir_p!(Path.join(path, "data"))
    File.mkdir_p!(Path.join(path, "control"))
    File.write!(Path.join(path, "debian-binary"), "2.0\n")
  end

  defp clean_workdir(path, _release) do
    File.rm_rf!(path)
  end

  defp unpack_release(dest, archive_path, release) do
    path = Path.join([dest, "data", "opt", to_string(release.name)])
    File.mkdir_p!(path)
    unpack(archive_path, path)
  end

  defp add_lifetime_scripts(path, release) do
    assigns = Map.from_struct(release)
    write_lifetime_script(path, "postinst", postinst_template(assigns))
    write_lifetime_script(path, "prerm", prerm_template(assigns))
  end

  defp write_lifetime_script(path, name, body) do
    file = Path.join([path, "control", name])
    debug("Writing #{name} script to: #{file}")
    File.write!(file, body)
    File.chmod!(file, 0o755)
  end

  defp add_init_script(path, release) do
    file = Path.join([path, "data", "etc", "init", "#{release.name}.conf"])
    debug("Writing upstart script to: #{file}")
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, upstart_template(Map.from_struct(release)))
  end

  defp handle_config(path, release) do
    original = Path.join([path, "data", "opt", to_string(release.name), "releases", to_string(release.version), "#{release.name}.conf"])
    target = Path.join([path, "data", "etc", "#{release.name}.conf"])
    final  = Path.join("/etc", "#{release.name}.conf")
    debug("Moving conffile #{original} to #{target}, symlinking #{final}")
    :ok = File.rename(original, target)
    :ok = File.ln_s(final, original)
  end

  defp add_control_file(path, release) do
    file = Path.join([path, "control", "control"])
    debug("Writing control file to: #{file}")
    File.write!(file, control_template(Map.from_struct(release)))
  end

  defp compress(path, dir, _release) do
    path = Path.join(path, dir)
    compress("#{path}.tar.gz", path)
  end

  defp build_package(path, release) do
    deb = archive_path(release, "deb")

    manifest = Path.join(path, "debian-binary")
    control  = Path.join(path, "control.tar.gz")
    data     = Path.join(path, "data.tar.gz")

    info("Writing deb package to: #{deb}")
    command("ar", ["-rc", deb, manifest, control, data])
  end

  ## Helpers

  defp archive_path(release, ext) do
    Path.join([release.output_dir, "releases", release.version, "#{release.name}.#{ext}"])
  end

  defp workdir, do: Path.join(Mix.Project.build_path, "package")

  defp unpack(from, to) do
    command(tar(), ["-zxf", from, "-C", to])
  end

  defp compress(where, what) do
    owner = ~w(--numeric-owner --owner 0 --numeric-owner --group 0)
    command(tar(), owner ++ ["-zcf", where, "."], cd: what)
  end

  defp command(name, args, opts \\ []) do
    case System.cmd(name, args, [stderr_to_stdout: true] ++ opts) do
      {result, 0} ->
        result
      {error, exit} ->
        error("Command #{name} exited with code: #{exit}:\n#{error}")
    end
  end

  defp tar() do
    case :os.type do
      {:unix, :darwin} -> "gtar"
      _                -> "tar"
    end
  end

  require EEx
  EEx.function_from_string(:defp, :postinst_template, """
  #!/bin/sh

  if $(id -u <%= @name %> &>/dev/null); then
    echo "Skipping adding user, since it already exists"
  else
    adduser --system <%= @name %> --group \
      --disabled-login --disabled-password \
      --home /opt/<%= @name %> --no-create-home || true
  fi

  chown -R <%= @name %>:<%= @name %> /opt/<%= @name %> || true

  if [ -e /etc/init.d/<%= @name %> ]; then
    echo "Found system service, skipping linking upstart"
  else
    ln -s /lib/init/upstart-job /etc/init.d/<%= @name %> || true
  fi

  echo "Restarting service"
  service <%= @name %> start || true
  service <%= @name %> restart || true
  """, [:assigns])

  EEx.function_from_string(:defp, :prerm_template, """
  #!/bin/sh

  if (service <%= @name %> status | grep stop &> /dev/null); then
    echo "Service already stopped"
  else
    echo "Stopping service"
    service <%= @name %> stop || true
  fi
  """, [:assigns])

  EEx.function_from_string(:defp, :control_template, """
  Package: <%= @name %>
  Version: <%= @version %>
  License: Apache2
  Architecture: amd64
  Priority: extra
  Section: misc
  Maintainer: michal@muskala.eu
  Description: Automatically packaged by DistilleryPackage
    <%= @version %>
    HexView backend
  """, [:assigns])

  EEx.function_from_string(:defp, :upstart_template, """
  description "HexView backend"

  setuid <%= @name %>
  setgid <%= @name %>

  start on runlevel [2345]
  stop on runlevel [016]

  expect fork
  respawn

  env MIX_ENV=prod
  export MIX_ENV

  env HOME=/opt/<%= @name %>
  export HOME

  env LC_ALL="en_US.utf8"
  export LC_ALL

  pre-start exec /bin/sh /opt/<%= @name %>/bin/<%= @name %> start

  post-stop exec /bin/sh /opt/<%= @name %>/bin/<%= @name %> stop
  """, [:assigns])
end
