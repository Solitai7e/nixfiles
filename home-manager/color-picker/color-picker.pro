TEMPLATE =  app
QT       += core gui widgets
CONFIG   += warn_on strict_c++ c++17

TARGET = color-picker
SOURCES += color-picker.cpp

isEmpty(PREFIX) {
  PREFIX = /usr/local
}
target.path = $$PREFIX/bin
INSTALLS += target

desktop_entry.path = $$PREFIX/share/applications
desktop_entry.files = color-picker.desktop
INSTALLS += desktop_entry
