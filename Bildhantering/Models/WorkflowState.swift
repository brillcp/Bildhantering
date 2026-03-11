import Foundation

enum WorkflowState {
    case setup                              // volumes not yet configured
    case dashboard                          // waiting for Nikon card
    case cardDetected(CardInfo)             // card mounted, show file count
    case projectPicker(CardInfo)            // user picks/creates project
    case metadataForm(CardInfo, String?)    // confirm fotodatum/proj/arbnamn
    case importing(ImportJob)               // copying in progress
    case summary(ImportResult)             // done — show stats + eject
}
