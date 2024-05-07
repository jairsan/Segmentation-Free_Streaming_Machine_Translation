for job in $(seq $1 $2);do
    qdel $job
done

