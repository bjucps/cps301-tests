curl https://codeload.github.com/sschaub/cps301/zip/master --output cps301.zip --silent
rm -r cps301
unzip -q cps301.zip 
rm cps301.zip
mv cps301-master cps301
bash /cps301/util/setup.sh
mysqladmin shutdown

