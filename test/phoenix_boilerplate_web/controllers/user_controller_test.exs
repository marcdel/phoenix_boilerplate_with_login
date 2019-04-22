defmodule PhoenixBoilerplateWeb.UserControllerTest do
  use PhoenixBoilerplateWeb.ConnCase, async: true

  alias PhoenixBoilerplate.Accounts
  alias PhoenixBoilerplate.Accounts.User
  alias PhoenixBoilerplate.Repo

  setup do
    Repo.insert(%User{id: 1, name: "Marc", username: "marcdel"})
    Repo.insert(%User{id: 2, name: "Jackie", username: "jackie"})

    :ok
  end

  describe "when user is logged in" do
    test "GET /users/:id", %{conn: conn} do
      user1 = Accounts.get_user(1)
      conn = sign_in(conn, user1)
      conn1 = get(conn, Routes.user_path(conn, :show, "1"))
      assert html_response(conn1, 200) =~ user1.name

      user2 = Accounts.get_user(2)
      conn = sign_in(conn, user2)
      conn2 = get(conn, Routes.user_path(conn, :show, "2"))
      assert html_response(conn2, 200) =~ user2.name
    end

    test "GET /users/:id cannot see another user's profile", %{conn: conn} do
      user1 = Accounts.get_user(1)
      conn = sign_in(conn, user1)

      conn = get(conn, Routes.user_path(conn, :show, "1"))
      assert html_response(conn, 200)

      conn = get(conn, Routes.user_path(conn, :show, "2"))
      assert conn.status == 302
      assert conn.halted == true
    end
  end

  describe "when user is not logged in" do
    test "GET /users/:id redirects", %{conn: conn} do
      conn1 = get(conn, Routes.user_path(conn, :show, "1"))
      assert html_response(conn1, 302) =~ "redirected"

      conn2 = get(conn, Routes.user_path(conn, :show, "2"))
      assert html_response(conn2, 302) =~ "redirected"
    end
  end

  test "GET /users/new", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :new))
    assert html_response(conn, 200) =~ "Name"
    assert html_response(conn, 200) =~ "Username"
  end

  test "POST /users", %{conn: conn} do
    conn =
      post(
        conn,
        Routes.user_path(conn, :create),
        user: %{
          "name" => "Jane",
          "username" => "janedoe",
          credential: %{
            email: "jane@email.com",
            password: "password"
          }
        }
      )

    assert get_flash(conn, :info) =~ "Jane created!"
    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == Routes.user_path(conn, :show, id)

    assert %User{id: id, username: "janedoe"} = Accounts.get_user_by_email("jane@email.com")
  end

  test "POST /users with invalid data", %{conn: conn} do
    invalid_user = %{"name" => "Jane", "username" => ""}
    create_conn = post(conn, Routes.user_path(conn, :create), user: invalid_user)
    assert html_response(create_conn, 200) =~ "Oops, something went wrong!"
  end
end
