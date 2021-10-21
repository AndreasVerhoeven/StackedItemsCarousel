Pod::Spec.new do |s|
    s.name             = 'StackedItemsCarousel'
    s.version          = '1.0.0'
    s.summary          = 'A carousel of stacked items as seen in iMessage - implemented using a UICollectionViewLayout'
    s.homepage         = 'https://github.com/AndreasVerhoeven/StackedItemsCarousel'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Andreas Verhoeven' => 'cocoapods@aveapps.com' }
    s.source           = { :git => 'https://github.com/AndreasVerhoeven/StackedItemsCarousel.git', :tag => s.version.to_s }
    s.module_name      = 'StackedItemsCarousel'

    s.swift_versions = ['5.0']
    s.ios.deployment_target = '13.0'
    s.source_files = 'Sources/*.swift'
end
