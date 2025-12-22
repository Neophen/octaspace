defmodule Octaspace.Accounts do
  use Ash.Domain,
    otp_app: :octaspace

  resources do
    resource Octaspace.Accounts.Token
    resource Octaspace.Accounts.User
    resource Octaspace.Accounts.ApiKey
  end
end
