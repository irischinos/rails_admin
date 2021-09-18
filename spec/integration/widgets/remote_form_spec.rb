require 'spec_helper'

RSpec.describe 'Remote form widget', type: :request, js: true do
  subject { page }

  context 'with filtering select widget' do
    let(:league) { FactoryBot.create :league }
    let(:division) { FactoryBot.create :division, league: league }
    before do
      RailsAdmin.config Division do
        field :league
      end
      RailsAdmin.config League do
        field :name
      end
    end

    it 'creates an associated record' do
      visit new_path(model_name: 'division')
      click_link 'Add a new League'
      is_expected.to have_content 'New League'
      fill_in 'Name', with: 'National League'
      find('#modal .save-action').click
      expect(find('#division_custom_league_id', visible: false).value).to eq League.first.id.to_s
      expect(League.pluck(:name)).to eq ['National League']
    end

    it 'updates the associated record' do
      visit edit_path(model_name: 'division', id: division.id)
      expect(find('#division_custom_league_id', visible: false).value).to eq league.id.to_s
      click_link 'Edit this League'
      is_expected.to have_content "Edit League '#{league.name}'"
      fill_in 'Name', with: 'National League'
      find('#modal .save-action').click
      expect(find('#division_custom_league_id', visible: false).value).to eq league.id.to_s
      expect(league.reload.name).to eq 'National League'
    end
  end

  context 'with filtering multi-select widget' do
    let(:leagues) { FactoryBot.create_list :league, 2 }
    let!(:division) { FactoryBot.create :division, name: 'National League Central', league: leagues[0] }
    before do
      RailsAdmin.config League do
        field :divisions
      end
      RailsAdmin.config Division do
        field :name
        field :league
      end
    end

    it 'creates an associated record and adds into selection' do
      visit edit_path(model_name: 'league', id: leagues[1].id)
      click_link 'Add a new Division'
      is_expected.to have_content "New Division"
      fill_in 'Name', with: 'National League West'
      find(%(#division_custom_league_id option[value="#{leagues[0].id}"]), visible: false).select_option
      find('#modal .save-action').click
      is_expected.to have_css('.ra-multiselect-selection option', text: 'National League West')
      new_division = Division.where(name: 'National League West').first
      expect(new_division).not_to be nil
      expect(find('#league_division_ids', visible: false).value).to eq [new_division.id.to_s]
    end

    it 'updates an unselected associated record with leaving it unselected' do
      visit edit_path(model_name: 'league', id: leagues[1].id)
      find('.ra-multiselect-collection option', text: division.name).double_click
      is_expected.to have_content "Edit Division 'National League Central'"
      fill_in 'Name', with: 'National League East'
      find('#modal .save-action').click
      is_expected.to have_css('.ra-multiselect-collection option', text: 'National League East')
      expect(find('#league_division_ids', visible: false).value).to eq []
      expect(division.reload.name).to eq 'National League East'
    end

    it 'updates a selected associated record' do
      visit edit_path(model_name: 'league', id: leagues[0].id)
      find('.ra-multiselect-selection option', text: division.name).double_click
      is_expected.to have_content "Edit Division 'National League Central'"
      fill_in 'Name', with: 'National League East'
      find('#modal .save-action').click
      expect(find('#league_division_ids', visible: false).value).to eq [division.id.to_s]
      expect(division.reload.name).to eq 'National League East'
    end
  end

  context 'with file upload' do
    before do
      RailsAdmin.config NestedFieldTest do
        field :field_test
      end
      RailsAdmin.config FieldTest do
        field :carrierwave_asset
      end
    end

    it 'submits successfully' do
      visit new_path(model_name: 'nested_field_test')
      click_link 'Add a new Field test'
      is_expected.to have_content 'New Field test'
      attach_file "Carrierwave asset", file_path('test.jpg')
      find('#modal .save-action').click
      is_expected.to have_no_css('#modal')
      expect(FieldTest.first.carrierwave_asset.file.size).to eq 1575
    end
  end
end
