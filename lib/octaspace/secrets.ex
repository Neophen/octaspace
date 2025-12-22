defmodule Octaspace.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Octaspace.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:octaspace, :token_signing_secret)
  end
end
