
To send a binary file do:

% cat test-data/login.bin - | nc host port

The "-" makes sure nc does not close the getSocket as soon as the contents have been sent.
