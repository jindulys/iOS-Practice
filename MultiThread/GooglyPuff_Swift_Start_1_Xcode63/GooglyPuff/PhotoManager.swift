//
//  PhotoManager.swift
//  GooglyPuff
//
//  Created by Bjørn Olav Ruud on 06.08.14.
//  Copyright (c) 2014 raywenderlich.com. All rights reserved.
//

import Foundation

/// Notification when new photo instances are added
let PhotoManagerAddedContentNotification = "com.raywenderlich.GooglyPuff.PhotoManagerAddedContent"
/// Notification when content updates (i.e. Download finishes)
let PhotoManagerContentUpdateNotification = "com.raywenderlich.GooglyPuff.PhotoManagerContentUpdate"

typealias PhotoProcessingProgressClosure = (completionPercentage: CGFloat) -> Void
typealias BatchPhotoDownloadingCompletionClosure = (error: NSError?) -> Void

private let _sharedManager = PhotoManager()

class PhotoManager {
  class var sharedManager: PhotoManager {
    return _sharedManager
  }

  private var _photos: [Photo] = []
  var photos: [Photo] {
    // FIXME: Not thread-safe
    return _photos
  }

  func addPhoto(photo: Photo) {
    // FIXME: Not thread-safe
    _photos.append(photo)
    dispatch_async(dispatch_get_main_queue()) {
      self.postContentAddedNotification()
    }
  }

  func downloadPhotosWithCompletion(completion: BatchPhotoDownloadingCompletionClosure?) {
    dispatch_async(GlobalUserInitiatedQueue) {
      var storedError: NSError?
      var downloadGroup = dispatch_group_create()
      
      for address in [OverlyAttachedGirlfriendURLString,
                      SuccessKidURLString,
                      LotsOfFacesURLString] {
        let url = NSURL(string: address)
        dispatch_group_enter(downloadGroup)
        let photo = DownloadPhoto(url: url!) {
          image, error in
          if error != nil {
            storedError = error
          }
          dispatch_group_leave(downloadGroup)
        }
        PhotoManager.sharedManager.addPhoto(photo)
      }
      dispatch_group_wait(downloadGroup, DISPATCH_TIME_FOREVER)
      dispatch_async(GlobalMainQueue) {
        if let completion = completion {
          completion(error: storedError)
        }
      }
    }
  }

  private func postContentAddedNotification() {
    NSNotificationCenter.defaultCenter().postNotificationName(PhotoManagerAddedContentNotification, object: nil)
  }
}
