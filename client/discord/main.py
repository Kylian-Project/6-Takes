import discord
from discord.ext import tasks, commands
import mysql.connector
import asyncio
from io import BytesIO

# Configuration de la base de données
DB_CONFIG = {
    'host': 'mysql-6takes.alwaysdata.net',
    'user': '6takes',
    'password': '6Takes2025**',
    'database': '6takes_db'
}

# ID du salon où poster les feedbacks
DISCORD_CHANNEL_ID = 1368689969752838276  # Remplace par l'ID du canal Discord

# Ton token
DISCORD_TOKEN = 'MTM2ODY4Nzg1MzU2Mjc1NzI3MQ.GHkGkm._GX440GXuvCFjsmIJjCOmZoBRbJQV4DlyUgQWY'

intents = discord.Intents.default()
intents.message_content = True
intents.messages = True
bot = commands.Bot(command_prefix='!', intents=intents)

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

# Désactiver le help command par défaut
bot.remove_command('help')

class FeedbackView(discord.ui.View):
    def __init__(self, feedback_id, message_to_delete):
        super().__init__(timeout=None)
        self.feedback_id = feedback_id
        self.message_to_delete = message_to_delete

    @discord.ui.button(label="🗑 Supprimer", style=discord.ButtonStyle.danger)
    async def delete_button(self, interaction: discord.Interaction, button: discord.ui.Button):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("DELETE FROM feedback WHERE id = %s", (self.feedback_id,))
            conn.commit()
            await self.message_to_delete.delete()
            await interaction.response.send_message("✅ Feedback supprimé avec succès.", ephemeral=True)
        except Exception as e:
            await interaction.response.send_message("❌ Erreur lors de la suppression.", ephemeral=True)
        finally:
            cursor.close()
            conn.close()

# Commande de clear pour supprimer les messages
@bot.command(name='clear')
@commands.has_permissions(manage_messages=True)
async def clear(ctx, amount: int):
    if amount < 1:
        await ctx.send("❌ Vous devez supprimer au moins un message.")
        return
    
    deleted = await ctx.channel.purge(limit=amount + 1)  # +1 pour inclure le message de commande
    await ctx.send(f"🗑 {len(deleted) - 1} messages supprimés.", delete_after=5)

@clear.error
async def clear_error(ctx, error):
    if isinstance(error, commands.MissingPermissions):
        await ctx.send("❌ Vous n'avez pas la permission de gérer les messages.")
    elif isinstance(error, commands.BadArgument):
        await ctx.send("❌ Veuillez entrer un nombre valide de messages à supprimer.")
    else:
        await ctx.send("❌ Une erreur est survenue lors de la suppression des messages.")

@bot.event
async def on_ready():
    print(f"Connecté en tant que {bot.user}")
    check_feedbacks.start()

@tasks.loop(seconds=5)
async def check_feedbacks():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM feedback WHERE discord_send = 0 ORDER BY created_at ASC")
    feedbacks = cursor.fetchall()

    if not feedbacks:
        conn.close()
        return

    channel = bot.get_channel(DISCORD_CHANNEL_ID)
    if not channel:
        print("Canal introuvable")
        conn.close()
        return

    for feedback in feedbacks:
        embed = discord.Embed(title="📝 Nouveau Feedback", color=0x9b59b6)
        feedback['type'] = feedback['type'].upper()
        embed.add_field(name="Type", value=feedback['type'], inline=True)
        embed.add_field(name="Message", value=feedback['message'], inline=False)
        embed.set_footer(text=f"ID: {feedback['id']} - Reçu le {feedback['created_at']}")

        file = None
        if feedback['screenshot']:
            image_data = BytesIO(feedback['screenshot'])
            file = discord.File(fp=image_data, filename="screenshot.png")
            embed.set_image(url="attachment://screenshot.png")

        view = FeedbackView(feedback_id=feedback['id'], message_to_delete=None)
        message = await channel.send(embed=embed, file=file, view=view)
        view.message_to_delete = message

        cursor.execute("UPDATE feedback SET discord_send = 1 WHERE id = %s", (feedback['id'],))
        conn.commit()

    conn.close()


bot.run(DISCORD_TOKEN)
