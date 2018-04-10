class Openresty < Formula
  desc "Scalable Web Platform by Extending NGINX with Lua"
  homepage "https://openresty.org"
  VERSION = "1.13.6.1".freeze
  url "https://openresty.org/download/openresty-#{VERSION}.tar.gz"
  sha256 "d1246e6cfa81098eea56fb88693e980d3e6b8752afae686fab271519b81d696b"

  option "with-debug", "Compile with support for debug logging but without proper gdb debugging symbols"
  option "with-postgresql", "Compile with ngx_http_postgres_module"
  option "with-iconv", "Compile with ngx_http_iconv_module"
  option "with-slice", "Compile with ngx_http_slice_module"

  depends_on "pcre"
  depends_on "postgresql" => :optional
  depends_on "geoip"

  skip_clean "site"
  skip_clean "pod"
  skip_clean "nginx"
  skip_clean "luajit"

  def self.core_modules
    [
        ["gzip-static",        "http_gzip_static_module",   "Build with Gzip static support"],
        ["no-pool-nginx",      nil,                         "Build without nginx-pool (valgrind debug memory)"],
        ["passenger",          nil,                         "Build with Phusion Passenger support"],
        ["stream-ssl-preread", "stream_ssl_preread_module", "Build with Stream without terminating SSL/TLS support"],
        ["stream-geoip",       "stream_geoip_module",       "Build with Stream GeoIP support"],
        ["stream-realip",      "stream_realip_module",      "Build with Stream RealIP support"],
    ]
  end

  def self.third_party_modules
  {
      "anti-ddos" => "Build with Anti-DDoS support",
      "array-var" => "Build with Array Var support",
      "auto-keepalive" => "Build with Auto Disable KeepAlive support",
      "cache-purge" => "Build with Cache Purge support",
      "dav-ext" => "Build with HTTP WebDav Extended support",
      "dosdetector" => "Build with detecting DoS attacks support",
      "echo" => "Build with Echo support",
      "eval" => "Build with Eval support",
      "extended-status" => "Build with Extended Status support",
      "geoip2" => "Build with GeoIP2 support",
      "headers-more" => "Build with Headers More support",
      "healthcheck" => "Build with Healthcheck support",
      "http-flood-detector" => "Build with Var Flood-Threshold support",
      "log-if" => "Build with Log-if support",
      "lua" => "Build with LUA support",
      "mod-zip" => "Build with HTTP Zip support",
      "mogilefs" => "Build with HTTP MogileFS support",
      "mp4-h264" => "Build with HTTP MP4/H264 support",
      "mruby" => "Build with MRuby support",
      "notice" => "Build with HTTP Notice support",
      "php-session" => "Build with Parse PHP Sessions support",
      "tarantool" => "Build with Tarantool upstream support",
      "push-stream" => "Build with HTTP Push Stream support",
      "realtime-req" => "Build with Realtime Request support",
      "redis" => "Build with Redis support",
      "redis2" => "Build with Redis2 support",
      "rtmp" => "Build with RTMP support",
      "tcp-proxy" => "Build with TCP Proxy support",
      "small-light" => "Build with Small Light support",
      "unzip" => "Build with UnZip support",
      "upload" => "Build with Upload support",
      "upload-progress" => "Build with Upload Progress support",
      "upstream-order" => "Build with Order Upstream support",
      "ustats" => "Build with Upstream Statistics (HAProxy style) support",
      "var-req-speed" => "Build with Var Request-Speed support",
      "vod" => "Build with VOD on-the-fly MP4 Repackager support",
      "websockify" => "Build with Websockify support",
      "xsltproc" => "Build with XSLT Transformations support",
  }
  end

  def install
    # Configure
    cc_opt = "-I#{HOMEBREW_PREFIX}/include -I#{Formula["pcre"].opt_include} -I#{Formula["openresty-openssl"].opt_include}"
    ld_opt = "-L#{HOMEBREW_PREFIX}/lib -L#{Formula["pcre"].opt_lib} -L#{Formula["openresty-openssl"].opt_lib}"

    args = %W[
      --prefix=#{prefix}
      --pid-path=#{var}/run/openresty.pid
      --lock-path=#{var}/run/openresty.lock
      --conf-path=#{etc}/openresty/nginx.conf
      --http-log-path=#{var}/log/nginx/access.log
      --error-log-path=#{var}/log/nginx/error.log
      --with-cc-opt=#{cc_opt}
      --with-ld-opt=#{ld_opt}
      --with-pcre-jit
      --without-http_rds_json_module
      --without-http_rds_csv_module
      --without-lua_rds_parser
      --with-ipv6
      --with-stream
      --with-stream_ssl_module
      --with-http_v2_module
      --with-mail
      --with-mail_ssl_module
      --without-mail_pop3_module
      --without-mail_imap_module
      --without-mail_smtp_module
      --with-http_stub_status_module
      --with-http_realip_module
      --with-http_addition_module
      --with-http_auth_request_module
      --with-http_secure_link_module
      --with-http_random_index_module
      --with-http_geoip_module
      --with-http_gzip_static_module
      --with-http_sub_module
      --with-http_dav_module
      --with-http_flv_module
      --with-http_mp4_module
      --with-http_gunzip_module
      --with-threads
      --with-luajit-xcflags=-DLUAJIT_NUMMODE=2\ -DLUAJIT_ENABLE_LUA52COMPAT
      --with-dtrace-probes
      --with-file-aio
      --with-http_degradation_module
      --with-http_image_filter_module
      --with-http_ssl_module
      --with-http_xslt_module
    ]

    core_modules.each do |arr|
      option "with-#{arr[0]}", arr[2]
    end

    third_party_modules.each do |name, desc|
      option "with-#{name}-module", desc
      depends_on "#{name}-nginx-module" if build.with?("#{name}-module")
    end

    def patches
      patches = {}
      # https://github.com/openresty/no-pool-nginx
      if build.with?("no-pool-nginx")
        patches[:p2] = "https://raw.githubusercontent.com/openresty/no-pool-nginx/master/nginx-1.11.2-no_pool.patch"
      end
      if build.with?("extended-status-module")
        patches[:p1] = "https://raw.githubusercontent.com/nginx-modules/ngx_http_extended_status_module/master/extended_status-1.10.1.patch"
      end
      if build.with?("ustats-module")
        patches[:p1] = "https://raw.githubusercontent.com/nginx-modules/ngx_ustats_module/master/nginx-1.6.1.patch"
      end
      if build.with?("tcp-proxy-module")
        patches[:p1] = "https://raw.githubusercontent.com/yaoweibin/nginx_tcp_proxy_module/afcab76/tcp_1_8.patch"
      end
      patches
    end

    args << "--with-http_postgres_module" if build.with? "postgresql"
    args << "--with-http_iconv_module" if build.with? "iconv"
    args << "--with-http_slice_module" if build.with? "slice"
    args << "--with-debug" if build.with? "debug"
    args << "--with-http_perl_module" if build.with? "perl"

    # Core Modules
    self.class.core_modules.each do |arr|
      args << "--with-#{arr[1]}" if build.with?(arr[0]) && arr[1]
    end

    # Set misc module and mruby module both depend on nginx-devel-kit being compiled in
    if build.with?("set-misc-module") || build.with?("mruby-module") || build.with?("lua-module") || build.with?("array-var-module")
      args << "--add-module=#{HOMEBREW_PREFIX}/share/ngx-devel-kit"
    end

    # Third Party Modules
    self.class.third_party_modules.each_key do |name|
      if build.with?("#{name}-module")
        args << "--add-module=#{HOMEBREW_PREFIX}/share/#{name}-nginx-module"
      end
    end

    system "./configure", *args

    # Install
    system "make"
    system "make", "install"
  end

  plist_options :manual => "openresty"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_prefix}/bin/openresty</string>
            <string>-g</string>
            <string>daemon off;</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOS
  end

  test do
    system "#{bin}/openresty", "-V"
  end
end
