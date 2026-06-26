#include <QString>
#include <QColor>
#include <QApplication>
#include <QColorDialog>

int main(int argc, char *argv[]) {
  QApplication app(argc, argv);

  QColorDialog colorDialog;
  colorDialog.setOption(QColorDialog::DontUseNativeDialog);
  colorDialog.setOption(QColorDialog::NoButtons);
  colorDialog.setCurrentColor(QColor(255, 255, 255));
  colorDialog.setWindowTitle(QStringLiteral("Color Picker"));
  colorDialog.setWindowFlag(Qt::WindowContextHelpButtonHint, false);
  colorDialog.show();

  return app.exec();
}
