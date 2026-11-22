{ config, ... }:

let
  d = "/var/lib/stacks/cartero";
  cfg = ./cartero;

  anubisPolicy = config.sops.templates."anubis-policy.yaml".path;
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/redis 0755 root root -"
    "d ${d}/data 0755 root root -"
  ];

  sops.secrets = {
    "cartero-config/jev_api_key" = {
      sopsFile = ../secrets/cartero-config.yaml;
      key = "jev_api_key";
      mode = "0400";
    };
    "cartero-config/discord_bot_token" = {
      sopsFile = ../secrets/cartero-config.yaml;
      key = "discord_bot_token";
      mode = "0400";
    };
    "cartero-config/bluesky_password" = {
      sopsFile = ../secrets/cartero-config.yaml;
      key = "bluesky_password";
      mode = "0400";
    };
    "cartero-config/telegram_bot_token" = {
      sopsFile = ../secrets/cartero-config.yaml;
      key = "telegram_bot_token";
      mode = "0400";
    };
    "cartero-config/app_token" = {
      sopsFile = ../secrets/cartero-config.yaml;
      key = "app_token";
      mode = "0400";
    };
  };

  sops.templates."anubis-policy.yaml" = {
    restartUnits = [ "podman-anubis-news.service" ];
    mode = "0400";
    uid = 1000;
    gid = 0;
    content = ''
      bots:
        - name: cartero-app
          headers_regex:
            X-Cartero-Client: "^${config.sops.placeholder."cartero-config/app_token"}$"
          action: ALLOW
        - name: cartero-app-ua
          user_agent_regex: "(?i)cartero/"
          action: ALLOW
        - name: mobile-feeds
          path_regex: ^/feed\.(rss|atom|json)$
          action: ALLOW
        - name: health
          path_regex: ^/health$
          action: ALLOW
        - name: api
          path_regex: ^/search(/|\?|$)
          action: ALLOW
        - name: ai-crawlers
          user_agent_regex: "(?i:gptbot|chatgpt-user|oai-searchbot|claudebot|claude-web|anthropic-ai|ccbot|bytespider|amazonbot|google-extended|applebot-extended|perplexity|cohere-ai|diffbot|imagesiftbot|omgilibot|timpibot|youbot|ai2bot|meta-externalagent|velenpublicwebcrawler|keenable)"
          action: DENY
        - name: seo-crawlers
          user_agent_regex: "(?i:ahrefsbot|semrushbot|mj12bot|dotbot|dataforseobot|petalbot)"
          action: DENY
        - name: everything-else
          path_regex: .*
          action: CHALLENGE
          challenge:
            algorithm: argon2id
            difficulty: 8
    '';
  };

  sops.templates."cartero-config.toml" = {
    restartUnits = [ "podman-cartero.service" ];
    content = builtins.replaceStrings
      [
        "@JEV_API_KEY@"
        "@DISCORD_BOT_TOKEN@"
        "@BLUESKY_PASSWORD@"
        "@TELEGRAM_BOT_TOKEN@"
      ]
      [
        config.sops.placeholder."cartero-config/jev_api_key"
        config.sops.placeholder."cartero-config/discord_bot_token"
        config.sops.placeholder."cartero-config/bluesky_password"
        config.sops.placeholder."cartero-config/telegram_bot_token"
      ]
      (builtins.readFile (cfg + "/config.toml"));
  };

  virtualisation.oci-containers.containers = {
    cartero-redis = {
      image = "redis/redis-stack:latest";
      volumes = [ "${d}/redis:/data" ];
      ports = [ "127.0.0.1:6379:6379" ];
    };

    cartero = {
      image = "ghcr.io/dracarys18/cartero:latest";
      environment = {
        TZ = "UTC";
        OLLAMA_HOST = "http://host.docker.internal:11434";
        CARTERO_QUEUE_PREFIX = "cartero";
      };
      environmentFiles = [ config.sops.secrets."cartero".path ];
      volumes = [
        "${config.sops.templates."cartero-config.toml".path}:/app/config.toml:ro"
        "${cfg}/myfeed.opml:/app/myfeed.opml:ro"
        "${cfg}/keywords.json:/app/keywords.json:ro"
        "${cfg}/spamlist.txt:/app/spamlist.txt:ro"
        "${cfg}/templates:/app/templates:ro"
        "${d}/data:/app/data"
      ];
      ports = [ "127.0.0.1:8034:8080" ];
      cmd = [
        "-config"
        "/app/config.toml"
      ];
      dependsOn = [
        "postgres"
        "cartero-redis"
        "flaresolverr"
      ];
      extraOptions = [
        "--pull=newer"
        "--add-host=host.docker.internal:host-gateway"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
    };

    anubis-news = {
      image = "ghcr.io/techarohq/anubis:latest";
      environment = {
        BIND = ":8923";
        TARGET = "http://cartero:8080";
        PUBLIC_URL = "https://news.karthihegde.dev";
        POLICY_FNAME = "/etc/anubis/policy.yaml";
        CUSTOM_REAL_IP_HEADER = "CF-Connecting-IP";
      };
      volumes = [ "${anubisPolicy}:/etc/anubis/policy.yaml:ro" ];
      extraOptions = [ "--pull=newer" ];
      dependsOn = [ "cartero" ];
    };

    cloudflare-tunnel = {
      image = "cloudflare/cloudflared:latest";
      cmd = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      environmentFiles = [ config.sops.secrets."cartero".path ];
      extraOptions = [ "--pull=newer" ];
      autoStart = true;
    };

    cartero-reader = {
      image = "ghcr.io/jina-ai/reader:latest";
      autoStart = false;
      extraOptions = [
        "--pull=newer"
        "--memory=2g"
        "--memory-swap=2g"
        "--shm-size=1gb"
        "--cpus=2"
        "--security-opt=seccomp=unconfined"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
    };
  };
}
