require 'spec_helper'
require 'open-uri'
describe "Graphite", :js => true do

	type = "Graphite"
	name = "carbon.agents.graphite-a.cache.queues"
	graphite_host = "http://192.168.122.219"
	metric = "#{type}~#{name}" 

	begin
                URI.parse(graphite_host).read
        rescue Errno::ECONNREFUSED,Errno::EHOSTUNREACH => e
                raise StandardError, "\n\nYou can't test the Graphite endpoint at #{graphite_host} unless it's live, dummy. \n\n#{e}\n\n"
        end

	before :each do 
		add_config "backends: [{ type: '#{type}', settings: {url: '#{graphite_host}'}}]"
		test_config type
	end

        context "refresh metrics" do
                include_examples "refresh metrics", type
        end

        context "standard" do
                it_behaves_like "a graph", "standard", metric
        end

        context "stacked" do
                it_behaves_like "a graph", "stacked", metric
        end

        context "horizon" do
                it_behaves_like "a graph", "horizon", metric
        end

	it "returns valid graphite errors if provoked" do
		visit "/metric/?metric=#{metric}&start=-1337"
		json = JSON.parse(page.text)
		expect(json).to include "error"
		expect(json["error"]).to include "Graphite Exception raised"
	end
end

describe "broken graphite" do
	it "doesn't work with an unconnectable graphite instance" do
		add_config "backends: [{ type: 'graphite', settings: { url: 'http://idontwork.nope.org'}}]"
		visit "/refresh"
		expect(page).to have_css "div.alert-danger"
		expect(page).to have_content "Error retrieving Graphite metrics"
	end
end