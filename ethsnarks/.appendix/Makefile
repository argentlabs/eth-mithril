all:
	@echo Read Makefile, figure out what to do...

first-mil-primes.txt: primes1.txt
	cat primes1.txt  | grep -Eo '\s([0-9])+\s' > first-mil-primes.txt

primes1.txt: primes1.zip
	unzip primes1.zip

primes1.zip:
	wget -O $@ http://primes.utm.edu/lists/small/millions/primes1.zip
