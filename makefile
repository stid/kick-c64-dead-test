BUILD_PATH = bin
KICKASS_BIN = /opt/develop/stid/c64/KickAssembler/KickAss.jar
.PHONY : build

all: build

build: clean
	java -jar ${KICKASS_BIN} -odir ../${BUILD_PATH} -log ./${BUILD_PATH}/buildlog.txt -showmem ./src/main.asm
	cartconv -t ulti -name "dead-test" -i ${BUILD_PATH}/main.prg -o ${BUILD_PATH}/dead-test.crt

cardbin: build
	cartconv -i ${BUILD_PATH}/dead-test.crt -o ${BUILD_PATH}/dead-test.bin

clean:
	rm -Rf ${BUILD_PATH}

orig:
	java -jar ${KICKASS_BIN} -odir ../${BUILD_PATH} -log ../${BUILD_PATH}/buildlog.txt -showmem ./src/781220.asm
	cartconv -t ulti -name "dead-test" -i ${BUILD_PATH}/781220.prg -o ${BUILD_PATH}/dead-test.crt
