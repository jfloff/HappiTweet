let i=1
let lines=336
while read p;do
	cd /mnt/nimbus/glusterfs/users/1/8/cluster169518
	curl -O ${p}
	for file in /mnt/nimbus/glusterfs/users/1/8/cluster169518/tweets*.gz
	do
		hadoop dfs -put $file /tmp/ist169518 < /dev/null
	done
	echo "Downloaded $i / $lines total files "
	let i=$i+1
  	rm tweets* 
done < dataset_file_list.txt