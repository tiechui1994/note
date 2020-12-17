import datetime
from enum import Enum
import faker
import pymysql
import collections


def namedtuple(typename, fields, default_values=()):
    T = collections.namedtuple(typename, fields)
    T.__new__.__defaults__ = (None,) * len(fields)
    if isinstance(default_values, collections.Mapping):
        prototype = T(**default_values)
    else:
        prototype = T(*default_values)
    T.__new__.__defaults__ = tuple(prototype)
    return T


db = pymysql.Connect(host='127.0.0.1', user='root', password='abc123_', port=3306, database='test',
                     charset='utf8', sql_mode=None, connect_timeout=3600, autocommit=True)

cursor = db.cursor(cursor=pymysql.cursors.DictCursor)
Column = namedtuple('Column', ['name', 'type', 'args'])

# faker = faker.Faker(locale='zh_CN')
faker = faker.Faker(locale=['en_US', 'zh_CN'])


class Type(Enum):
    COUNTRY = 'country'
    COUNYTRY_CODE = 'country_code'
    PROVINCE = 'province'  # 省
    CITY = 'city'  # 市
    DISTRICT = 'district'  # 区
    STREET = 'street'  # 街道
    COMMUNITY = 'community'  # 小区
    ADDRESS = 'address'  # 地址

    MALE = 'male'
    FEMAILE = 'female'
    NAME = 'name'

    PHONE = 'phone'
    EMAIL = 'email'

    IP = 'ip'
    URL = 'url'
    IMAGE = 'image'

    CHROME = 'chrome'
    FIREFOX = 'firefox'
    SAFARI = 'safari'
    OPERA = 'opera'

    DATE = 'date'  # 日期


funcs = {
    Type.COUNTRY: faker.country,
    Type.COUNYTRY_CODE: faker.country_code,
    Type.CITY: faker.city_suffix,  # 市
    Type.STREET: faker.street_name,  # 街道
    Type.COMMUNITY: faker.street_address,  # 小区
    Type.ADDRESS: faker.address,

    Type.MALE: faker.name_male,
    Type.FEMAILE: faker.name_female,
    Type.NAME: faker.name,

    Type.PHONE: faker.phone_number,
    Type.EMAIL: faker.safe_email,

    Type.IP: faker.ipv4,
    Type.URL: faker.uri,
    Type.IMAGE: faker.image_url,

    Type.CHROME: faker.chrome,
    Type.FIREFOX: faker.firefox,
    Type.SAFARI: faker.safari,
    Type.OPERA: faker.opera,

    Type.DATE: faker.date_between,
}

if 'zh_CN' in faker.locales:
    funcs.update({
        Type.PROVINCE: faker.province,  # 省
        Type.DISTRICT: faker.district,  # 区
    })


def insert(table: str, colmns: list, count: int):
    def call(item: Column):
        if item.args:
            val = funcs[item.type](*item.args)
            return "'" + str(val) + "'"
        else:
            val = funcs[item.type]()
            return "'" + str(val) + "'"

    while count >= 0:
        size = 100
        if count < 100:
            size = count
        values = []
        for _ in range(0, size):
            value = list(map(lambda item: call(item), colmns))
            values.append('(%s)' % (','.join(value)))
        count -= 100

        keys = list(map(lambda key: key.name, colmns))
        sql = "INSERT INTO %s (%s) VALUES %s" % (table, ','.join(keys), ','.join(values))
        print(sql)
        cursor.execute(sql)


if __name__ == '__main__':
    colums = [
        Column(name='username', type=Type.NAME),
        Column(name='time', type=Type.DATE, args=(datetime.date(2012, 1, 1),
                                                  datetime.date(2020, 12, 31)))
    ]

    insert('teacher', colums, 2920)