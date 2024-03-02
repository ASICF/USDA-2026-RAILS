import React from 'react';

// Greeting Logic 
function Greeting({ first_name }) {
  const greet = () => {
    const now = new Date();
    const today = new Date().setHours(0, 0, 0, 0);

    const morning = new Date(today);
    const noon = new Date(today).setHours(12, 0, 0, 0);
    const evening = new Date(today).setHours(17, 0, 0, 0);
    const night = new Date(today).setHours(20, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (now >= morning && now < noon) {
      return `Good Morning, ${first_name} ! 👋`
    } else if (now >= noon && now < evening) {
      return `Good Afternoon, ${first_name}! 👋`
    } else if (now >= evening && now < night) {
      return `Good Evening, ${first_name}! 👋`
    } else {
      return `Good Night, ${first_name}! 👋`
    }
  };

  return (
    <div>
      {greet()}
    </div>
  );
}

export default Greeting;