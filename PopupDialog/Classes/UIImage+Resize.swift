//
//  UIImage+Resize.swift
//  testOperations
//
//  Created by LYH on 12/8. (original: Trevor Harmon)
//  Copyright © 2016년 YK. All rights reserved.
//

import UIKit

extension UIImage {
	// Resizes the image according to the given content mode, taking into account the
	// image's orientation
	public func resizedImage(size:CGSize, contentMode:UIViewContentMode ,quality:CGInterpolationQuality = .default) -> UIImage? {

		let hRatio = size.width / self.size.width
		let vRatio = size.height / self.size.height
		let ratio : CGFloat

		switch(contentMode) {
		case .scaleAspectFit :
			ratio = min(hRatio, vRatio)
		case .scaleAspectFill :
			ratio = max(hRatio, vRatio)
		default :
			assertionFailure("Unsupported content mode: \(contentMode)")
			return nil
		}

		let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
		return resizedImage(size: newSize, quality: quality)
	}

	public func resizedImage(size newSize:CGSize, quality:CGInterpolationQuality = .default) -> UIImage? {
		let drawTransposed : Bool
		switch(self.imageOrientation) {
		case .left, .leftMirrored, .right, .rightMirrored :
			drawTransposed = true
		default :
			drawTransposed = false
		}
		let transform = self.transformForOrientation(size: newSize)
		return resizedImage(size: newSize, transform: transform, drawTransposed: drawTransposed, quality: quality)
	}

	public func resizedImage(size newSize:CGSize, transform:CGAffineTransform, drawTransposed transpose:Bool = false, quality:CGInterpolationQuality = .default) -> UIImage? {
		let scale = max(1.0, self.scale)

		let newRect = CGRect(origin: .zero, size: CGSize(width: newSize.width * scale, height: newSize.height * scale)).integral
		let transposedRect = CGRect(origin: .zero, size: CGSize(width: newRect.size.height, height: newRect.size.width))
		guard let imageRef = self.cgImage else {
			assertionFailure("self.cgImage returned nil")
			return nil
		}

		// Fix for a colorspace / transparency issue that affects some types of
		// images. See here: http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/comment-page-2/#comment-39951

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmap = CGContext(data: nil, width: Int(newRect.size.width), height: Int(newRect.size.height), bitsPerComponent: 8, bytesPerRow: Int(newRect.size.width) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

		// Rotate and/or flip the image if required by its orientation
		bitmap.concatenate(transform)

		// Set the quality level to use when rescaling
		bitmap.interpolationQuality = quality

		// Draw into the context; this scales the image
		bitmap.draw(imageRef, in: transpose ? transposedRect : newRect)

		// Get the resized image from the context and a UIImage
		guard let newImageRef = bitmap.makeImage() else {
			assertionFailure("bitmap.makeImage() returned nil")
			return nil
		}

		let newImage = UIImage(cgImage: newImageRef, scale: self.scale, orientation: .up)

		return newImage
	}


	fileprivate func transformForOrientation(size newSize:CGSize) -> CGAffineTransform {
		var transform = CGAffineTransform.identity

		switch(self.imageOrientation) {
		case .down, .downMirrored :
			transform = transform.translatedBy(x: newSize.width, y: newSize.height).rotated(by: CGFloat(M_PI))
		case .left, .leftMirrored :
			transform = transform.translatedBy(x: newSize.width, y: 0).rotated(by: CGFloat(M_PI_2))
		case .right, .rightMirrored :
			transform = transform.translatedBy(x: 0, y: newSize.height).rotated(by: CGFloat(-M_PI_2))
		default :
			break
		}

		switch(self.imageOrientation) {
		case .upMirrored, .downMirrored :
			transform = transform.translatedBy(x: newSize.width, y: 0).scaledBy(x: -1, y: 1)
		case .leftMirrored, .rightMirrored :
			transform = transform.translatedBy(x: newSize.height, y: 0).scaledBy(x: -1, y: 1)
		default :
			break
		}
		return transform
	}
}
