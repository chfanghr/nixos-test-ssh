{
  name = "ssh-test";

  nodes = {
    machineA = { pkgs, lib, ... }:
      let keyFile = "/tmp/id_ed25519"; in {
        systemd = {
          tmpfiles.settings."10-ssh-key".${keyFile}.f = {
            user = "root";
            group = "root";
            mode = "0400";
            argument = builtins.readFile ./id_ed25519;
          };

          services.ssh-into-b = {
            path = [ pkgs.openssh ];
            script = ''
              ssh -i ${keyFile} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@machineB -- hello
            '';
            serviceConfig.Type = "oneshot";
          };
        };

        system.stateVersion = "25.05";
      };

    machineB = { lib, pkgs, ... }: {
      services.openssh = {
        enable = true;

        settings.PermitRootLogin = "yes";
      };

      users.users.root = {
        packages = [ pkgs.hello ];
        openssh.authorizedKeys.keyFiles = [ ./id_ed25519.pub ];
      };

      system.stateVersion = "25.05";
    };
  };

  testScript = ''
    machineB.wait_for_unit("default.target")
    machineB.wait_for_unit("sshd.service")

    machineA.wait_for_unit("default.target")
    machineA.succeed("systemctl start ssh-into-b")
  '';
}
