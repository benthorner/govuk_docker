authenticating-proxy: bundle-authenticating-proxy government-frontend
	$(GOVUK_DOCKER) run $@-lite bin/rails runner 'User.first || User.create'
	$(GOVUK_DOCKER) run $@-lite env RAILS_ENV=test bin/rails runner 'User.first || User.create'
