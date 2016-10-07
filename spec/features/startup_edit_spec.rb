require 'rails_helper'

feature 'Startup Edit' do
  let(:founder) { create :founder, confirmed_at: Time.now }
  let(:co_founder) { create :founder, confirmed_at: Time.now }
  let!(:startup) { create :startup }

  let(:new_product_name) { Faker::Lorem.words(rand(3) + 1).join ' ' }
  let(:new_product_description) { Faker::Lorem.words(12).join(' ').truncate(Startup::MAX_PRODUCT_DESCRIPTION_CHARACTERS) }
  let(:new_deck) { Faker::Internet.domain_name }

  before :each do
    # Add founder as founder of startup.
    startup.founders << founder

    # Log in the founder.
    visit new_founder_session_path
    fill_in 'founder_email', with: founder.email
    fill_in 'founder_password', with: 'password'
    click_on 'Sign in'
    visit edit_founder_startup_path

    # founder should now be on his startup edit page.
  end

  context 'Founder visits edit page of his startup' do
    scenario 'Founder updates all required fields' do
      fill_in 'startup_product_name', with: new_product_name
      fill_in 'startup_product_description', with: new_product_description
      fill_in 'startup_presentation_link', with: new_deck

      click_on 'Update startup profile'

      # Wait for page to load before checking database.
      expect(page).to have_content(new_product_name)

      startup.reload

      expect(startup.product_name).to eq(new_product_name)
      expect(startup.product_description).to eq(new_product_description)
      expect(startup.presentation_link).to eq(new_deck)
    end

    scenario 'Founder clears all required fields' do
      fill_in 'startup_product_name', with: ''
      click_on 'Update startup profile'

      expect(page).to have_text('Please review the problems below')
      expect(page).to have_selector('div.form-group.startup_product_name.has-error')
    end

    scenario 'Founder adds a valid co-founder to the startup' do
      fill_in 'cofounder_email', with: co_founder.email
      click_on 'Add as co-founder'

      expect(page).to have_selector('.founders-table', text: co_founder.email)
      co_founder.reload
      expect(co_founder.startup).to eq(startup)
      open_email(co_founder.email)
      expect(current_email.subject).to eq('SVApp: You have been added as startup cofounder!')
    end

    scenario 'Non-admin founder views delete startup section' do
      expect(page).to have_text('Only the team leader can delete a startup\'s profile')
    end

    scenario 'Founder looks to delete his approved startup as startup_admin' do
      # change startup admin to this founder
      startup.admin.update(startup_admin: false)
      founder.update(startup_admin: true)
      startup.reload
      founder.reload

      visit edit_founder_startup_path
      expect(page).to have_text('To delete your startup timeline, contact your SV.CO representative.')
    end
  end
end
