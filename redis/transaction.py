import redis

# reids connection
conn = redis.StrictRedis(host='127.0.0.1', port=6379, db=0)
conn.set("redis", 1)
print(conn.get("redis"))

pool = redis.ConnectionPool(host='127.0.0.1', port=6379, db=0)
conn = redis.Redis(connection_pool=pool)
print(conn.get("redis"))

# pipeline
pip = conn.pipeline()
pip.set("1", 10)
pip.set("2", 20)
pip.execute()

# pub/sub
conn.publish("channel", "java")  # 发布消息

pubsub = conn.pubsub()
pubsub.subscribe("channel")  # 订阅
pubsub.psubscribe("c*l")  # 订阅(模式)
pubsub.unsubscribe("channel")  # 取消订阅
pubsub.punsubscribe("c*")  # 取消订阅(模式)
pubsub.get_message()  # 获取消息
