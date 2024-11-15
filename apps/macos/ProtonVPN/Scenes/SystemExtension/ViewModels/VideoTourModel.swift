//
//  Created on 03/03/2023.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import AVFoundation
import Combine

class VideoTourModel {
    enum VideoFile {
        case systemExtension

        var rawValue: String {
            switch self {
            case .systemExtension:
                if #available(macOS 15, *) {
                    return "https://protonvpn.com/download/macos/resources/videos/sequoia-os-final/sequoia-os-final.m3u8"
                } else if #available(macOS 13, *) {
                    return "https://protonvpn.com/download/resources/videos/ventura-os-final/ventura-os-final.m3u8"
                } else {
                    return "https://protonvpn.com/download/resources/videos/monterey-os-final/monterey-os-final.m3u8"
                }
            }
        }
    }

    private let videoFile: VideoFile

    private lazy var urlAsset: AVURLAsset = {
        let videoUrl = URL(string: videoFile.rawValue)!
        return AVURLAsset(url: videoUrl)
    }()

    lazy var size: CGSize = {
        guard let track = urlAsset.tracks(withMediaType: .video).first else {
            return .zero
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }()

    lazy var player = {
        let playerItem = AVPlayerItem(asset: urlAsset)
        let player = AVQueuePlayer(playerItem: playerItem)
        videoLooper = AVPlayerLooper(player: player,
                                     templateItem: playerItem)
        return player
    }()
    var videoLooper: AVPlayerLooper?

    init(videoFile: VideoFile) {
        self.videoFile = videoFile
    }

    func onAppear() {
        player.play()
        player.rate = 0.5
    }
}
