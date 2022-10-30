
all: u2scli debug

RCom.o: RCom.h RCom.cpp
	g++ RCom.cpp -c -o RCom.o

U2S.o: U2S.h U2S.cpp
	g++ U2S.cpp -c -o U2S.o

u2scli: RCom.o U2S.o u2scli.cpp
	g++ U2S.o RCom.o u2scli.cpp -o u2scli

debug: RCom.o U2S.o U2S_Debug.h U2S_Debug.cpp
	g++ U2S.o RCom.o U2S_Debug.cpp -g -o debug

clean:
	rm -rf U2S.o
	rm -rf RCom.o
	rm -rf u2scli
	rm -rf debug


