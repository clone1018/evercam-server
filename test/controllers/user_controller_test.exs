defmodule EvercamMedia.UserControllerTest do
  use EvercamMedia.ConnCase

  test "POST /v1/users - creates the user and returns the json" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    params = %{ "user" => %{ firstname: "John" , lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password" } }
    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 201)

    assert response["user"]["firstname"] == "John"
    assert response["user"]["lastname"] == "Doe"
    assert response["user"]["country_id"] == country.id
    refute response["user"]["id"] == ""
    refute response["user"]["api_id"] == ""
    refute response["user"]["api_id"] == ""
    assert response["user"]["confirmed_at"] == nil
  end

  test "POST /v1/users - returns a conflict error for a duplicate user name" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    {:ok, _user } = EvercamMedia.Repo.insert(%User{ firstname: "John", lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password"})

    params = %{ "user" => %{ firstname: "John" , lastname: "Dade", 
        email: "john@dade.com", username: "johnd", country_id: country.id, password: "some_password" } }

    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 409)
    assert response["errors"]["username"], ["has already been taken"]
  end

  test "POST /v1/users - returns a conflict error for a duplicate email address" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    {:ok, _user } = EvercamMedia.Repo.insert(%User{ firstname: "John", lastname: "Doe", 
        email: "johnd@example.com", username: "johnd", country_id: country.id, password: "some_password"})

    params = %{ "user" => %{ firstname: "John" , lastname: "Dade", 
        email: "johnd@example.com", username: "johndade", country_id: country.id, password: "some_password" } }

    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 409)
    assert response["errors"]["email"], ["has already been taken"]
  end

  test "POST /v1/users - returns a HTTP 400 for blank params" do
    params = %{ "user" => %{ firstname: "" , lastname: "", email: "", username: "", country_id: "", password: "" } }

    conn = conn()
      |> post("/v1/users", params)

    json_response(conn, 400)
  end

  test "POST /v1/users - when key is supplied, creates the user, sets the confirmed_at field and returns the json" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    params = %{ "user" => %{ firstname: "John" , lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password"}, key: "some_key_here" }
    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 201)

    refute response["user"]["confirmed_at"] == ""
  end

  test "PUT /v1/users/:id - updates the User with the supplied id" do
    {:ok, country} = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    {:ok, user} =  EvercamMedia.Repo.insert(%User{firstname: "John" , lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, 
        password: "some_password", api_id: "api_id", api_key: "api_key"})
    params = %{"user" => %{ firstname: "Jonnathan" }}

    conn = conn()
      |> Plug.Conn.put_req_header("x-api-id", user.api_id)
      |> Plug.Conn.put_req_header("x-api-key", user.api_key)
      |> put("/v1/users/#{user.id}", params)

    response = json_response(conn, 200)

    assert response["user"]["firstname"] == "Jonnathan"
    assert response["user"]["lastname"] == "Doe"
  end
end