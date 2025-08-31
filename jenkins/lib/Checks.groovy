
def start(String name, String title, String summary) {
  publishChecks name: name, title: title, status: 'IN_PROGRESS', summary: summary
}

def ok(String name, String summary) {
  publishChecks name: name, status: 'COMPLETED', conclusion: 'SUCCESS', summary: summary
}

def fail(String name, String summary) {
  publishChecks name: name, status: 'COMPLETED', conclusion: 'FAILURE', summary: summary
}

return this
