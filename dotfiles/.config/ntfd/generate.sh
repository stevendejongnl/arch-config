#! /bin/bash

generate () {
    echo "Generate"
    echo '' > $HOME/.config/ntfd/config.toml

    IFSBAK=$IFS
    IFS=" "

    base_config="$(cat $HOME/.config/ntfd/config-base.toml)"
    echo $base_config > $HOME/.config/ntfd/config.toml

    location_ip=$(curl -s ipinfo.io/ | jq ".ip")
    location_geo=$(curl -s ipinfo.io/ | jq ".loc")

    if [ '"87.215.29.34"' == $location_ip ]; then
    # if [ '"52.3552,4.8789"' == $location_geo ]; then
        echo 'city_id = "2753557" # Houten' >> $HOME/.config/ntfd/config.toml
        echo "Houten"
    else
        echo 'city_id = "2760133" # Aalsmeer' >> $HOME/.config/ntfd/config.toml
        echo "Aalsmeer"
    fi

    IFS=$IFSBAK
    config=$(cat $HOME/.config/ntfd/config.toml)
}

generate

while [ "100" -gt "${#config}" ]; do
    sleep 10
    generate
done
