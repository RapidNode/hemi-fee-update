#!/bin/bash

while true; do
    # Fetch the current fee
    raw_fee=$(curl -sSL "https://mempool.space/testnet/api/v1/fees/mempool-blocks" | jq '.[0].medianFee')

    # Check if fee was retrieved successfully
    if [[ -n "$raw_fee" && "$raw_fee" != "null" ]]; then
        static_fee=$(printf "%.0f" "$raw_fee")

        # Update the fee in /root/hemi-env
        if awk -v new_fee="$static_fee" '/^POPM_STATIC_FEE=/{sub(/[0-9]+$/, new_fee)}1' /root/hemi-env > /root/hemi-env.tmp; then
            mv /root/hemi-env.tmp /root/hemi-env

            # Restart each hemi service
            for i in {0..10}; do
                if sudo systemctl restart hemi-$i.service; then
                    echo "Restarted hemi-$i.service with updated fee."
                else
                    echo "Failed to restart hemi-$i.service."
                fi
            done
            break # Exit the loop once the fee is updated and services are restarted
        else
            echo "Failed to update /root/hemi-env."
        fi
    else
        echo "Failed to fetch static fee. Retrying in 10 seconds."
        sleep 20
    fi
done
