//
//  CustomTabBar.swift
//  KBOCare
//
//  Created by Hyunwoo Jeon on 12/13/23.
//

import UIKit

/* 
 Custom Tab Bar Item 선택 시 실행될 delegate
 */
protocol CustomTabbarDelegate {
    func click(_ index: Int)
   
}

/*
 Tab Item의 종류 정의
 */
enum TabItem: Int {
    case today
    case health
    case challenge
    case commerce
}

/*
 
 TabItem
 Custom TabBar에 사용될 TabItem enum
 defaultImage, selectedImage, title을 지정한다.
 
 */
extension TabItem {
    
    /* default image */
    var defaultImage: UIImage? {
        switch self {
            
        case .today:
            return UIImage(named: "todayOff")
        case .health:
            return UIImage(named: "healthCheckOff")
        case .challenge:
            return UIImage(named: "challengeOff")
        case .commerce:
            return UIImage(named: "commerceOff")
        }
    }
    
    /* selected Image */
    var selectedImage: UIImage? {
        switch self {
            
        case .today:
            return UIImage(named: "todayOn")
        case .health:
            return UIImage(named: "healthCheckOn")
        case .challenge:
            return UIImage(named: "challengeOn")
        case .commerce:
            return UIImage(named: "commerceOn")
        }
    }
    
    /* 타이틀 */
    var title: String? {
        switch self {
            
        case .today:
            "오늘"
        case .health:
            "건강"
        case .challenge:
            "챌린지"
        case .commerce:
            "커머스"
        }
    }
}

final class CustomTabBar: UIView {
    
    var delegate: CustomTabbarDelegate? = nil
    
    /*
     Custom TabBar StackView ( horizontal , fillEqually )
     */
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually

        return stackView
    }()
    
    private let tabItems: [TabItem]
    private var tabButtons = [UIView]()
    private var selectedIndex = 0 {
        didSet { updateUI() }
    }
    
    private func updateUI() {
        tabItems
            .enumerated()
            .forEach { i, item in
                let isButtonSelected = selectedIndex == i
                let image = isButtonSelected ? item.selectedImage : item.defaultImage
                let font = isButtonSelected ? ThemeFont.KBFGTextMedium(ofSize: 11) : ThemeFont.KBFGTextLight(ofSize: 11)
                
                let view = tabButtons[i]
                if let imageView = view.viewWithTag(1) as? UIImageView {
                    imageView.image = image
                }
                
                if let titleLabel = view.viewWithTag(2) as? UILabel {
                    titleLabel.font = font
                }
                
            }
    }
    
    init(tabItems: [TabItem]) {
        self.tabItems = tabItems
        super.init(frame: .zero)
        setUp()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setUp() {
        // 함수 종료 직전에 실행
        defer { updateUI() }
        
        /* UI 조정 */
        tabItems
            .enumerated()
            .forEach { i, item in
            
                let backgroundView = UIView()
                let image = item.defaultImage
                let imageView = UIImageView(image: image)
                imageView.tag = 1
                backgroundView.addSubview(imageView)
                
                let title = item.title
                let titleLabel = UILabel()
                titleLabel.text = title
                titleLabel.font = ThemeFont.KBFGTextLight(ofSize: 11)
                titleLabel.textColor = UIColor(hexCode: "26282C")
                titleLabel.tag = 2
                backgroundView.addSubview(titleLabel)
                
                let button = UIButton()
                button.addAction { [weak self] in
                    self?.selectedIndex = i
                    self?.delegate?.click(i)
                }
                backgroundView.addSubview(button)

                tabButtons.append(backgroundView)
                stackView.backgroundColor = UIColor.white
                stackView.addArrangedSubview(backgroundView)
                
                imageView.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                button.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
                    imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 26.0),
                    imageView.heightAnchor.constraint(equalToConstant: 26.0),
                    
                    titleLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
                    titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor),
                    titleLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
                    
                    button.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                    button.rightAnchor.constraint(equalTo: backgroundView.rightAnchor),
                    button.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
                    button.leftAnchor.constraint(equalTo: backgroundView.leftAnchor)
                ])
            }
        
        addSubview(stackView)
        
        let shadowBorder = UIImageView()
        shadowBorder.backgroundColor = UIColor(hexCode: "000000", alpha: 0.4)
        addSubview(shadowBorder)
        
        shadowBorder.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
                
        NSLayoutConstraint.activate([
            shadowBorder.leftAnchor.constraint(equalTo: leftAnchor),
            shadowBorder.rightAnchor.constraint(equalTo: rightAnchor),
            shadowBorder.topAnchor.constraint(equalTo: topAnchor),
            shadowBorder.heightAnchor.constraint(equalToConstant: 6),
            
            stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12.0),
            stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.topAnchor.constraint(equalTo: shadowBorder.bottomAnchor),
        ])
    }
}
