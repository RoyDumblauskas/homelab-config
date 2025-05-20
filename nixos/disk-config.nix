{
  disko.devices = {
    disk = {
      x = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # boot
            ESP = {
              size = "64M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # root
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        # options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank";
          };
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "/nix";
            mountpoint = "/nix";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "/persist";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}
