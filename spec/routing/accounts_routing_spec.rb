require "spec_helper"

describe UsersController do
  describe "routing" do

    it "route to #index should not exist" do
      expect(get: "/admin/users/1/accounts").not_to be_routable
    end
    
    it "route to #show should not exist" do
      expect(get: "/admin/users/1/accounts/2").not_to be_routable
    end

    it "routes to #new" do
      get("/admin/users/1/accounts/new").should route_to("accounts#new",
        user_id: '1')
    end

    it "routes to #edit" do
      get("/admin/users/1/accounts/2/edit").should route_to("accounts#edit", 
        user_id: "1", id: '2')
    end

    it "routes to #create" do
      post("/admin/users/1/accounts").should route_to("accounts#create", 
        user_id: '1')
    end

    it "routes to #update" do
      put("/admin/users/1/accounts/2").should route_to("accounts#update", 
        user_id: "1", id: '2')
    end

    it "routes to #destroy" do
      delete("/admin/users/1/accounts/2").should route_to("accounts#destroy", 
        user_id: "1", id: '2')
    end

  end
end
