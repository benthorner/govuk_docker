maslow: bundle-maslow publishing-api
	$(GOVUK_DOCKER) run $@-lite bin/rake db:setup
	$(GOVUK_DOCKER) run $@-lite bin/rails runner 'User.first || User.create'
	$(GOVUK_DOCKER) run $@-lite yarn
