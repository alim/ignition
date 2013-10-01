########################################################################
# The UsersController is the administrative controller for managing
# users of the web service. It is targeted for the service administrator
# and does not take the place of the Devise controller. The route is
# to this controller has been set to be contained within the /admin
# namespace.
########################################################################
class UsersController < ApplicationController

  # Before filters -----------------------------------------------------
  before_filter :authenticate_user!
  
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_users_class
    
  ######################################################################
  # GET /admin/users
  #
  # The index action will present a list of system users. It will allow
  # the system administrator to search for an acount by:
  # 
  # * email 
  # * frst_name
  # * last_name
  #
  # It will also enable filtering the view by user roles. All results
  # will be paginated. This action is designed only to be used via 
  # a web interface.
  ######################################################################
  def index
    @search_options = [
      ['Email', 'email'], 
      ['First name', 'first_name'],
      ['Last name', 'last_name']
    ]
    
    # Check to see if we want to search for a subset of users
    if params[:search].present? && params[:stype].present?
      
      # Check for the type of search we are doing
      case params[:stype]
      when 'email'
        @users = User.by_email(params[:search])
      when 'first_name'
        @users = User.by_first_name(params[:search])
      when 'last_name'  
        @users = User.by_last_name(params[:search])
      else # Unrecognized search type so return all
        @users = User.all
      end
      
    else # No search criteria, so we start off with all Users
      @users = User.all
    end

    if params[:role_filter].present?
      if params[:role_filter] == 'customer'
        @users =  @users.by_role(User::CUSTOMER)
      elsif params[:role_filter] == 'service_admin'
        @users =  @users.by_role(User::SERVICE_ADMIN)
      end
    end
    
  end
  
  ######################################################################
  # GET /admin/users/:id
  #
  # The show action displays the user record and a subset of the fields.
  # It does not show first login time, ip address, and token. 
  ######################################################################
  def show
    if @user.present?
      if @user.account.present?
        @user.account.get_customer  if @user.account.customer_id.present?
      end
    else
      flash[:error] = "We could not find the requested User record ID ##{params[:id]}"
      redirect_to users_url
    end
  end
  
  ######################################################################
  # GET /admin/users/:id
  #
  # The edit action will display a standard edit form for user account.
  ######################################################################
  def edit
    if !@user.present?
      redirect_to users_url, alert: "Could not find requested User account"
    end
  end
  
  ######################################################################
  # UPDATE /admin/users/:id
  #
  # The update method will modify the submitted attributes of the User
  # record. 
  ######################################################################
  def update
    @verrors = nil
    
    if @user.present?
      # Delete the password parameters if they have been submitted blank
      params[:user].delete(:password) if params[:user][:password].blank?
      params[:user].delete(:password_confirmation) if 
        params[:user][:password].blank? and 
        params[:user][:password_confirmation].blank?
        
      if @user.update_attributes(user_params)
        redirect_to user_url(@user), notice: "User account succesfully updated."
      else
        @verrors = @user.errors.full_messages
        render :edit
      end
    else
      flash[:alert] = "Could not find user account to update."
      redirect_to users_url
    end
  end
  
  ######################################################################
  # GET /admin/users/new
  #
  # The new action enables an administrator create a new user account.
  # It presents a new user account form and pre-populates the password
  # fields with a random 10 digit password.
  ######################################################################
  def new
    @user = User.new
    random_password = Devise.friendly_token.first(10)
    @user.password = random_password
    @user.password_confirmation = random_password
  end
  
  ######################################################################
  # POST /admin/users
  #
  # The create enables creation of a new user account by a service 
  # administrator. Once a new user account is created, the user will
  # receive an email message with the new account information. They
  # will be prompted to change their password on first login.
  ######################################################################
  def create
    @verrors = nil
      
    @user = User.new(user_params)
    if @user.save
      
      # Email user the account information
      UserMailer.new_account(@user).deliver    
      redirect_to @user, notice: "New user account created and user email sent."
      
    else
      @verrors = @user.errors.full_messages
      render action: 'new'
    end

  end
  
  ######################################################################
  # DELETE /admin/users/:id
  #
  # The destory action will delete the user. The user model should also
  # include any dependent destroy specifications.
  ######################################################################
  def destroy
    if @user.present?
      @user.destroy
      redirect_to users_url, notice: "User account - #{@user.email} - deleted."
    else
      flash[:alert] = "Could not find user account to destroy."
      redirect_to users_url
    end
  end
  
  ## PRIVATE INSTANCE METHODS ------------------------------------------
  private

  ####################################################################
  # Use callbacks to share common setup or constraints between actions.
  # We do the following actions:
  # * Try to lookup the resource
  # * Catch the error if not found and set instance variable to nil
  ####################################################################
  def set_user
    begin
      @user = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @user = nil
    end
  end

  
  ######################################################################
  # The set_users_class method sets an instance variable for the CSS
  # class that will highlight the menu item. 
  ######################################################################
  def set_users_class
    @users_active = "class=active" 
  end
  
  ######################################################################
  # Never trust parameters from the scary internet, only allow the 
  # white list through.
  ######################################################################
  def user_params
    params.require(:user).permit(
      :first_name, 
      :last_name,
      :phone,
      :email,
      :role,
      :password,
      :password_confirmation
    )
  end  
end
