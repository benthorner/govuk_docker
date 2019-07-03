require "spec_helper"
require_relative "../../lib/commands/run_this"

describe Commands::RunThis do
  let(:config_directory) { "spec/fixtures" }
  let(:service) { nil }
  let(:stack) { nil }
  let(:args) { nil }

  subject { described_class.new(stack, args, service, config_directory) }

  context "with a service that exists" do
    let(:service) { "example-service" }
    let(:stack) { "default" }

    let(:compose_command) { double }
    before { expect(Commands::Compose).to receive(:new).and_return(compose_command) }

    context "with no extra arguments" do
      let(:args) { [] }

      it "should run docker compose for one service when the service and stack exists" do
        expect(compose_command).to receive(:call).with(
          "run", "--rm", "--service-ports", "example-service-default"
        )
        subject.call
      end
    end

    context "with some extra arguments" do
      let(:args) { ["bundle", "exec", "rake", "lint"] }

      it "should run docker compose for one service when the service and stack exists" do
        expect(compose_command).to receive(:call).with(
          "run", "--rm", "--service-ports", "example-service-default",
          "env", "bundle", "exec", "rake", "lint"
        )
        subject.call
      end
    end
  end

  context "with a service that doesn't exist" do
    let(:service) { "no-example-service" }

    it "should fail" do
      expect { subject.call }.to raise_error(/Unknown service/)
    end
  end
end