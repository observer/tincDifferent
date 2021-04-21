{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.tincDifferent;

in

{

  options = {

    services.tincDifferent = {

      networks = mkOption {
        default = { };
        type = with types; attrsOf (submodule {
          options = {

            nodeName = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                Name of the Node in the tinc network.
              '';
            };

            port = mkOption {
              default = 655;
              type = types.int;
              description = ''
                TCP / UDP port used byt the tinc network (The Port 
                has to be supplied in the node configuration as well, 
                since the original tinc module takes the Port from 
                there).
              '';
            };

            ipv4Address = mkOption {
              default = null;
              type = types.nullOr types.str;
              description = ''
                IPv4 Address of the machine on the tinc network.
              '';
              example = "10.0.0.1";
            };

            ipv4Prefix = mkOption {
              default = null;
              type = types.nullOr types.int;
              description = ''
                IPv4 Prefix of the machine on the tinc network.
              '';
              example = 24;
            };

          };
        });

        description = ''
          Defines the tinc networks which will be started.
          Each network invokes a different daemon.
        '';
      };
    };

  };

  config = {

    networking.firewall = fold (a: b: a // b) { }
      (flip mapAttrsToList cfg.networks (network: data:
        {
          allowedTCPPorts = [ data.port ];
          allowedUDPPorts = [ data.port ];
        }
      ));

    services.tinc.networks = builtins.mapAttrs (network: data: { 
      name = data.nodeName; 
      hosts = let
      #  files        = builtins.readDir ("/etc/nixos/vpn/tinc/" + network);
      #  filenames    = builtins.attrNames files;
      #  filepaths    = map (x: "/etc/nixos/vpn/tinc/" + network + "/" + x) filenames;
      #  filecontents = map builtins.readFile filepaths;
      #  jsondata     = map (x: builtins.fromJSON x) filecontents;
      #  attrsetdata = builtins.listToAttrs jsondata;
        files = map (x: "/etc/nixos/vpn/tinc/" + network + "/" + x) (builtins.attrNames (builtins.readDir ("/etc/nixos/vpn/tinc/" + network +"/")));
        ## CHECK!! use builtins.readFile before import and check if we notice changes on rebuilds!
        attrsetdata = builtins.listToAttrs (map (x: lib.nameValuePair x.name x.config) (map (x: (import x).tinc) files));
      in attrsetdata;
    }) cfg.networks;

    #networking.interfaces = builtins.mapAttrs (network: data: { 
    #  "tinc.${network}".ipv4.routes = let
    #     files = map (x: "/etc/nixos/vpn/tinc/" + network + "/" + x) (builtins.attrNames (builtins.readDir ("/etc/nixos/vpn/tinc/" + network +"/")));
    #     routes = builtins.concatLists (map (x: x.ipv4) (map (x: (import x).routes) files));
    #  in routes;
    #}) cfg.networks;

    networking.interfaces = fold (a: b: a // b) { }
      (flip mapAttrsToList cfg.networks (network: data:
      {
        "tinc.${network}".ipv4 = {
          addresses = [
            {
              address      = data.ipv4Address;
              prefixLength = data.ipv4Prefix;
            }
          ];
          routes = let
            files = map (x: "/etc/nixos/vpn/tinc/" + network + "/" + x) (builtins.attrNames (builtins.readDir ("/etc/nixos/vpn/tinc/" + network +"/")));
            routes = builtins.concatLists (map (x: x.ipv4) (map (x: (import x).routes) files));
          in routes;
        };
      }
    ));

  };
}
