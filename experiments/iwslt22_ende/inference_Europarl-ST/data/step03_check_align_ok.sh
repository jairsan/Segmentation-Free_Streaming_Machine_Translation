cat aligned_dev.lst | while read fil;
do
if ! [ -f $fil ]; then
  echo $fil "does not exist."
fi
done

cat aligned_test.lst | while read fil;
do
if ! [ -f $fil ]; then
  echo $fil "does not exist."
fi
done
