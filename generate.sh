#!/bin/sh

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting M3U generation"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Using Ace Stream Engine: ${ACESTREAM_ENGINE_ADDR}"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Using HTTPAceProxy: ${HTTPACEPROXY_ADDR}"

# Function to convert comma-separated string to YAML array
# Note: The YAML library doesn't handle quotes well in arrays, so we use multiline format
csv_to_yaml_array() {
    if [ -z "$1" ]; then
        echo "[]"
    else
        # Generate multiline YAML array format without quotes
        echo ""
        echo "$1" | awk -F',' '{
            for(i=1; i<=NF; i++) {
                gsub(/^[ \t]+|[ \t]+$/, "", $i)  # trim whitespace
                printf "  - %s\n", $i
            }
        }'
    fi
}

# Export converted arrays for envsubst
export NAME_RX_FILTER_YAML=$(csv_to_yaml_array "$NAME_RX_FILTER")
export NAME_RX_BLACKLIST_YAML=$(csv_to_yaml_array "$NAME_RX_BLACKLIST")
export CATEGORIES_FILTER_YAML=$(csv_to_yaml_array "$CATEGORIES_FILTER")
export CATEGORIES_BLACKLIST_YAML=$(csv_to_yaml_array "$CATEGORIES_BLACKLIST")
export LANGUAGES_FILTER_YAML=$(csv_to_yaml_array "$LANGUAGES_FILTER")
export LANGUAGES_BLACKLIST_YAML=$(csv_to_yaml_array "$LANGUAGES_BLACKLIST")
export COUNTRIES_FILTER_YAML=$(csv_to_yaml_array "$COUNTRIES_FILTER")
export COUNTRIES_BLACKLIST_YAML=$(csv_to_yaml_array "$COUNTRIES_BLACKLIST")

# Substitute environment variables in config file
envsubst < /app/m3u_gen_acestream.yaml > /tmp/m3u_gen_acestream.yaml

# Run m3u_gen_acestream with substituted config
cd /app
./m3u_gen_acestream -c /tmp/m3u_gen_acestream.yaml

# Check if generation was successful
if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Generation successful"
    
    # Copy generated files to shared volume
    if [ -f /app/out/playlist_hls.m3u8 ]; then
        cp /app/out/playlist_hls.m3u8 /srv/m3u/
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Copied playlist_hls.m3u8"
    fi
    
    if [ -f /app/out/playlist_mpegts.m3u8 ]; then
        cp /app/out/playlist_mpegts.m3u8 /srv/m3u/
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Copied playlist_mpegts.m3u8"
    fi
    
    if [ -f /app/out/playlist_httpaceproxy.m3u8 ]; then
        cp /app/out/playlist_httpaceproxy.m3u8 /srv/m3u/
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Copied playlist_httpaceproxy.m3u8"
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - M3U files copied to /srv/m3u/"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - =========================================="
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Playlists available at:"
    echo "$(date '+%Y-%m-%d %H:%M:%S') -   http://localhost:${NGINX_PORT:-8080}/playlist_hls.m3u8"
    echo "$(date '+%Y-%m-%d %H:%M:%S') -   http://localhost:${NGINX_PORT:-8080}/playlist_mpegts.m3u8"
    echo "$(date '+%Y-%m-%d %H:%M:%S') -   http://localhost:${NGINX_PORT:-8080}/playlist_httpaceproxy.m3u8"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - =========================================="
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Generation failed with exit code $?"
fi
