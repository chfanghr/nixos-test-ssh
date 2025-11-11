{
  name = "ssh-test";

  nodes = {
    machineA = { pkgs, lib, ... }: {
      systemd.services.ssh-into-b = {
        path = [ pkgs.openssh ];
        script = ''
          ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@machineB -- hello
        '';
        serviceConfig.Type = "oneshot";
      };

      system.stateVersion = "25.05";
    };

    machineB = { lib, pkgs, ... }: {
      services.openssh = {
        enable = true;

        settings.PermitRootLogin = "yes";
      };

      users.users.root.packages = [ pkgs.hello ];

      security.pam.services.sshd.rootOK = true;

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
