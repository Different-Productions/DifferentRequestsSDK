// The contract's types are this SDK's public API. Every method takes and returns one, because
// wrapping them would mean maintaining a second set of models that says the same thing.
//
// Without this line that costs the developer doing an integration two dependencies and two imports
// before they can name the type `requests(...)` hands back — the client would resolve and its return
// values would not. Re-exporting makes `import DifferentRequests` the whole of what an integration
// needs, which is what a drop-in package owes the person dropping it in.
//
// `@_exported` is an underscored attribute, so it is not covered by Swift's source compatibility
// promise. That is the cost, and it is paid here in one line rather than by every consumer forever.
// If it is ever withdrawn, the fallback is for a host app to add the contract package alongside this
// one; nothing about the API changes, only what has to be imported to see it.
@_exported import DifferentRequestsProtos
