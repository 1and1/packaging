# refers to the definition of a release target
BRAND:=./branding/test.mk
include ${BRAND}

# refers to the definition of the release process execution environment
BUILDENV:=./env/test.mk
include ${BUILDENV}

# refers to whereabouts of code-signing keys
CREDENTIAL:=./credentials/test.mk
include ${CREDENTIAL}

include ./setup.mk

#######################################################

clean:
	rm -rf ${TARGET}

setup:
	bash -ex -c 'for f in */setup.sh; do $$f; done'

package: deb

publish: deb.publish


deb: ${DEB}
${DEB}: ${WAR} $(shell find deb/build -type f)
	./deb/build/build.sh
deb.publish: ${DEB} $(shell find deb/publish -type f)
	./deb/publish/publish.sh

	
${CLI}:
	@mkdir ${TARGET} || true
	wget -O $@.tmp ${JENKINS_URL}jnlpJars/jenkins-cli.jar
	mv $@.tmp $@



test.local.setup:
	# start a test Apache server that acts as package server
	# we'll refer to this as 'test.pkg.jenkins-ci.org'
	@mkdir -p ${TESTDIR} || true
	docker run --rm -t -i -p 9200:80 -v ${TESTDIR}:/var/www/html fedora/apache
%.test.up:
	# run this target for to set up the test target VM
	cd test; vagrant up --provision-with "" $*
	cd test; vagrant provision --provision-with "shell" $*; sleep 5
%.test.run:
	# run this target to just re-run the test against the currently running VM
	cd test; vagrant provision --provision-with serverspec $*
%.test.destroy:
	# run tis target to undo '%.test.up'
	cd test; vagrant destroy -f $*
%.test: %.test.up %.test.run %.test.destroy
	# run all the test goals in the order
