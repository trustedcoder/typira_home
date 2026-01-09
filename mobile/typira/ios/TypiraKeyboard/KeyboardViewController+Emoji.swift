import UIKit

// Constants for Cell Reuse
let EmojiCellIdentifier = "EmojiCell"
let EmojiHeaderIdentifier = "EmojiHeader"

extension KeyboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return emojiSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiSections[section].emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCellIdentifier, for: indexPath)
        
        // Reset
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        label.text = emojiSections[indexPath.section].emojis[indexPath.item]
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
        ])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: EmojiHeaderIdentifier, for: indexPath)
            
            header.subviews.forEach { $0.removeFromSuperview() }
            
            // Allow touches to pass through; Don't clip content (Label will overflow)
            header.isUserInteractionEnabled = false
            header.backgroundColor = .clear
            header.clipsToBounds = false
            
            let label = UILabel()
            label.text = "  \(emojiSections[indexPath.section].title)  " // Padding spaces
            label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            label.textColor = .systemGray
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            // Style the label box
            label.backgroundColor = UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 0.95)
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            
            header.addSubview(label)
            
            // Label Constraints for Overlay
            // Header Frame is tiny (0.1 width). Label must be positioned relative to leading.
            // Width is intrinsic based on text + padding.
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
                label.topAnchor.constraint(equalTo: header.topAnchor, constant: 4),
                label.heightAnchor.constraint(equalToConstant: 16)
            ])
            
            // Add internal padding to label text? UILabel doesn't support padding easily without subclass.
            // Use width constraint with multiplier? Or just let it be.
            // For now, auto-sized.
            
            return header
        }
        return UICollectionReusableView()
    }
    
    // MARK: - Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojiSections[indexPath.section].emojis[indexPath.item]
        self.didTapEmoji(emoji)
    }
    
    // MARK: - Flow Layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 29, height: 29)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // Items start at HeaderWidth(0.1) + Left(10) = 10.1
        return UIEdgeInsets(top: 24, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // Minimal width so it doesn't displace items.
        // Label will overflow visible bounds of header (clipsToBounds = false).
        // Sticky behavior pins this 0.1 wide strip to the left.
        return CGSize(width: 0.1, height: collectionView.bounds.height)
    }
    
    func didTapEmoji(_ emoji: String) {
        let proxy = self.textDocumentProxy
        proxy.insertText(emoji)
        historyManager.onTextTyped(emoji, proxy: proxy)
        
        // Simple animation feedback
        // Audio feedback provided by system usually
    }

    @objc func didTapCategoryIcon(_ sender: UIButton) {
        let section = sender.tag
        if section >= 0 && section < emojiSections.count {
            let indexPath = IndexPath(item: 0, section: section)
            self.emojiCollectionView?.scrollToItem(at: indexPath, at: .left, animated: true)
        }
    }
}
