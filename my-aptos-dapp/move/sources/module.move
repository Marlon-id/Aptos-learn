module RWA {

    // Structure to represent a tokenized Real-World Asset
    struct Token has key {
        id: u64,                    // Unique identifier for the token
        owner: address,             // Owner's address
        value: u64,                 // Value of the asset
        metadata: vector<u8>,       // Additional data like asset description
    }

    // Resource to store tokens in the owner's account
    resource struct TokenStore has key {
        tokens: vector<Token>,
    }

    // Initialize the account by creating an empty TokenStore
    public fun initialize_account(account: &signer) {
        move_to(account, TokenStore { tokens: vector::empty<Token>() });
    }

    // Mint a new RWA token
    public fun mint(
        account: &signer,
        id: u64,
        value: u64,
        metadata: vector<u8>
    ) {
        // Ensure the account has a TokenStore
        let token_store = borrow_global_mut<TokenStore>(signer::address_of(account));

        // Create the new token
        let token = Token { 
            id, 
            owner: signer::address_of(account), 
            value, 
            metadata 
        };

        // Add the new token to the owner's TokenStore
        vector::push_back(&mut token_store.tokens, token);
    }

    // Transfer an RWA token to another user
    public fun transfer(
        account: &signer,
        recipient: address,
        token_id: u64
    ) {
        // Get the token store of the sender
        let sender_store = borrow_global_mut<TokenStore>(signer::address_of(account));

        // Find the token index
        let token_index = Self::find_token(&sender_store.tokens, token_id);

        // Check if the token exists and is owned by the sender
        assert!(token_index.is_some(), 404);

        // Get the token
        let token = &mut sender_store.tokens[option::extract(token_index)];

        // Verify ownership
        assert!(token.owner == signer::address_of(account), 403);

        // Transfer ownership
        token.owner = recipient;

        // Update recipient's TokenStore
        let recipient_store = borrow_global_mut<TokenStore>(recipient);
        vector::push_back(&mut recipient_store.tokens, *token);
        // Remove the token from sender's TokenStore
        vector::remove(&mut sender_store.tokens, option::extract(token_index));
    }

    // Helper function to find a token by its ID
    public fun find_token(
        tokens: &vector<Token>,
        token_id: u64
    ): option::Option<u64> {
        let len = vector::length(tokens);
        let mut i = 0;

        while (i < len) {
            let token = &vector::borrow(tokens, i);
            if (token.id == token_id) {
                return option::some(i);
            }
            i = i + 1;
        }

        return option::none();
    }

    // Retrieve all tokens owned by an account
    public fun get_tokens(account: address): vector<Token> {
        let token_store = borrow_global<TokenStore>(account);
        return token_store.tokens;
    }
}
