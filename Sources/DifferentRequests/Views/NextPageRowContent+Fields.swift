extension NextPageRowContent {
  init(page: PageState, failureMessage: String) {
    self.init()
    self.page = page
    self.failureMessage = failureMessage
  }
}
