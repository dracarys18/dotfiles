# prerequisites/prerequisites.just — run all prerequisite steps before package installs

import 'terraform.just'
import 'kubectl.just'

# Run all prerequisites
prerequisites: prereq-terraform prereq-kubectl
