require 'spec_helper'

describe 'Authentication' do
  subject { page }

  describe 'on signin-page' do
    before {visit signin_path}

    it {should have_selector('h1',    text: 'Sign in')}
    it {should have_selector('title', text: 'Sign in')}

    describe 'with invalid information' do
      before {click_button 'Sign in'}

      it {should have_selector('title', text: 'Sign in')}
      it {should have_error_message('Invalid')}

      describe "after visiting another page" do
        before {click_link "Home"}
        it {should_not have_error_message}
      end
    end

    describe 'with valid information' do
      let(:user) {FactoryGirl.create(:user)}
      before {sign_in_using_form(user)}

      it {should have_selector('title', text: user.name)}

      it {should have_link('Users',       href: users_path)}
      it {should have_link('Profile',     href: user_path(user))}
      it {should have_link('Settings',    href: edit_user_path(user))}
      it {should have_link('Sign out',    href: signout_path)}
      it {should_not have_link('Sign in', href: signin_path)}

      describe 'followed by signout' do
        before {click_link 'Sign out'}
        it {should have_link('Sign in')}
      end
    end
  end

  describe "authorization" do
    describe "for non-signed-in users" do
      let(:user) {FactoryGirl.create(:user)}

      describe "when attempting to visit the edit page" do
        before do
          visit edit_user_path(user) # instead of going to edit user page, we should be taken to signin page
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

        describe "after signing in" do
          it "should render the desired edit page" do
            page.should have_selector('title', text: 'Edit user')
          end
        end
      end

      describe "when attempting to visit the users page" do
        before do
          visit users_path # instead of going to users page, we should be taken to signin page
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

        describe "after signing in" do
          it "should render the desired users page" do
            page.should have_selector('title', text: 'All users')
          end
        end
      end

      describe "in the Users controller" do
        describe "visiting the following page" do
          before {visit following_user_path(user)}
          it {should have_selector('title', text: 'Sign in')}
        end

        describe "visiting the followers page" do
          before {visit followers_user_path(user)}
          it {should have_selector('title', text: 'Sign in')}
        end

        describe "visiting the users index" do
          before {visit users_path}
          it {should have_selector('title', text: 'Sign in')}
        end
        describe "visiting the edit page" do
          before {visit edit_user_path(user)}
          it {should have_selector('title', text: "Sign in")}
        end

        describe "submitting to the update action" do
          before {put user_path(user)}
          specify {response.should redirect_to(signin_path)}
        end
      end

      describe "in the Relationships controller" do
        describe "submitting to the create action" do
          before {post relationships_path}
          specify {response.should redirect_to(signin_path)}
        end

        describe "submitting to the destroy action" do
          before {delete relationship_path(1)}
          specify {response.should redirect_to(signin_path)}
        end
      end
    end

    describe "for signed in users" do
      let(:user) {FactoryGirl.create(:user)}
      let(:another_user) {FactoryGirl.create(:user)}
      before {sign_in_using_form(user)}

      describe "in the Users controller" do
        describe "visiting another user's edit page" do
          before {visit edit_user_path(another_user)}
          it {should_not have_selector('title', text: full_title('Edit User'))}
        end

        describe "submitting to another user's update action" do
          before {put user_path(another_user)}
          specify do
            response.should redirect_to(root_path)
          end
        end
      end
    end

    describe "as non-admin user" do
      let(:user) {FactoryGirl.create(:user)}
      let(:non_admin) {FactoryGirl.create(:user)}
      before {sign_in_using_form non_admin}
      describe "submitting a delete request to the users#destroy action" do
        before {delete user_path(user)}
        specify {response.should redirect_to(root_path)}
      end
    end
  end

  describe "in the microposts controller" do
    describe "submitting to the create action" do
      before {post microposts_path}
      specify {response.should redirect_to(signin_path)}
    end

    describe "submitting to the destroy action" do
      before do
        micropost = FactoryGirl.create(:micropost)
        delete micropost_path(micropost)
      end
      specify {response.should redirect_to(signin_path)}
    end
  end
end
