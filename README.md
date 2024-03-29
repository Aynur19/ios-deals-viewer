# Реализация мобильного приложения по тестовому заданию от компании NTPro

1. [Описание тестового задания](./TaskDescription.md)
1. Минимальная телевая платформа: iOS 16.0
1. Отладка и тестирование проводилось на симуляторе (iPhone 13 Pro Max, iOS 16.0) и на реальном устройстве (iPhone 13 Pro Max, iOS 16.6)


## Детали

**Стек разработки:** ***Swift, SwiftUI, CoreDate, Concurrency, GDC, Combine***
- код полностью написан на `Swiift`
- UI полность реализован на `SwiftUI`
- хранение данных реализовано с использованием `CoreData`
- фоновые задачи и асинхронная обработка выполнена с применением `Concurrency` и `GDC`
- `Combine` использовался для отслеживания скроллинга списка


По условию задания, происходит имитация получения данных из сети в размере примерно 1 млн записей. Это имитируется через вызов функции:

```swift
server.subscribeToDeals { deals in

}
```

Каждый раз данные приходят пакетами - по 100 записей, пока не будут "отправлены" все. 
Хранить миллион записей в памяти телефона - не рационально. Поэтому сохраняем данные в БД используя `CoreData`. 

Если пытаться сразу сохранять данные в БД и в то же время обновлять список для пользователя, то это может вызвать задержки (лаги) на UI. 

Примечание: под обновлением списка для пользователя имеется ввиду вывод данных с нужной сортировкой и добавление записей, которые могли "втесаться" в текущий наблюдаемый диапазон.

Задержки (лаги), описанные выше, видимо, происходят потому, что частые потоки (очереди) на запись блокируют базу данных для чтения. Чтобы решить эту проблему, была введена сущность `DealTemporaryStorage`, которая временно хранила получаемые из "сервера" данные в оперативной памяти. При этом `DealsViewModel` каждые 2 секунды проверяет наличие данных у сущности `DealTemporaryStorage`, и если данные есть, то просиходит запись данных в БД и очистка данных и `DealTemporaryStorage`. Таким образом, каждые 2 секунды в базу данных записывается примерно 1500-2500 записей, а приложение не лагает при обновлении и скроллинге.

Дополнительная оптимизация для выполнения запросов к БД - добавление индексов к полям, по которым нужно проводить сортировку данных.

Следующая оптимизация: установка размера получаемых данных из БД (600 записей), и количество данных которые непосредственно готовы к использованию на стороне приложения ( 100 записей).

Дополнительная оптимизация: отслеживание скроллинга списка и подгрузка записей по необходимости. То есть если пользователь скроллит вниз списка - данные добавляются если надо. Если пользователь скроллит вверх - данные с конца могут удаляться и заменяться на актуальные таким образом, чтобы видимая чась записей + N-ное число сверху и снизу также становились актуальными.

Минус подхода: отслеживание скроллинга происходит только после остановки скроллинга, и значит, если быстро скроллить вверх, то станые данные могут быть неактуальными пока не обновятся. Но обновление происходит почти мгновенно после остановки скроллинга, так что считаю, что это приемлемый компромисс между актуальностью данных и отзывчивостью приложения.

При отладке приложения в конечной версии не было замечено каких либо лагов и торомзов. Дополнительно, код был проверен и отлажен со включенной настройкой `Tread Sanitizer` в схеме проекта и настройкой `Strict Concurrency Checking` в значении `Complete`. Предупреждений о `data racing` или `race conditions` и крэшей и вылетов замечено не было.
