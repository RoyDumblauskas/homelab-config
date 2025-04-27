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
        options.cachefile = "none";
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        # what should I be making a snapshot of here?!!!!
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zpool/local/zroot@blank$' || zfs snapshot zpool/local/zroot@blank";

        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
          };
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "/local/nix";
            mountpoint = "/local/nix";
          };
          "home" = {
            type = "zfs_fs";
            options.mountpoint = "/safe/home";
            mountpoint = "/safe/home";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "/safe/persist";
            mountpoint = "/safe/persist";
          };
        };
      };
    };
  };
}
